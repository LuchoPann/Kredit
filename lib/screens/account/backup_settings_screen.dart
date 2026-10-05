import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/app_theme.dart';
import '../../widgets/kredit_section_card.dart';

const _kBackupEnabled = 'backup_enabled';
const _kBackupFrequency = 'backup_frequency';
const _kBackupMode = 'backup_mode';
const _kBackupHour = 'backup_hour';
const _kBackupMinute = 'backup_minute';

/// Pantalla completa de respaldo (desde la lista principal de cuenta).
class BackupSettingsScreen extends StatelessWidget {
  const BackupSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Respaldo automático')),
      body: const BackupSettingsBody(),
    );
  }
}

/// Body embebible — funciona dentro del sheet de configuración Y como cuerpo
/// de [BackupSettingsScreen]. Sin Scaffold ni AppBar.
class BackupSettingsBody extends StatefulWidget {
  const BackupSettingsBody({super.key});

  @override
  State<BackupSettingsBody> createState() => _BackupSettingsBodyState();
}

class _BackupSettingsBodyState extends State<BackupSettingsBody> {
  bool _enabled = false;
  String _frequency = 'weekly';
  String _mode = 'overwrite';
  int _hour = 2;
  int _minute = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enabled = prefs.getBool(_kBackupEnabled) ?? false;
      _frequency = prefs.getString(_kBackupFrequency) ?? 'weekly';
      _mode = prefs.getString(_kBackupMode) ?? 'overwrite';
      _hour = prefs.getInt(_kBackupHour) ?? 2;
      _minute = prefs.getInt(_kBackupMinute) ?? 0;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBackupEnabled, _enabled);
    await prefs.setString(_kBackupFrequency, _frequency);
    await prefs.setString(_kBackupMode, _mode);
    await prefs.setInt(_kBackupHour, _hour);
    await prefs.setInt(_kBackupMinute, _minute);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuración de respaldo guardada')),
      );
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
      helpText: 'Hora del respaldo automático',
    );
    if (picked != null) {
      setState(() {
        _hour = picked.hour;
        _minute = picked.minute;
      });
    }
  }

  String get _frequencyLabel {
    return switch (_frequency) {
      'daily' => 'Diario',
      'biweekly' => 'Quincenal',
      'monthly' => 'Mensual',
      _ => 'Semanal',
    };
  }

  String get _timeLabel {
    final h = _hour.toString().padLeft(2, '0');
    final m = _minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get _nextBackupLabel {
    final now = DateTime.now();
    late DateTime next;
    switch (_frequency) {
      case 'daily':
        next = now.add(const Duration(days: 1));
      case 'biweekly':
        next = now.add(const Duration(days: 15));
      case 'monthly':
        next = DateTime(now.year, now.month + 1, now.day);
      default:
        next = now.add(const Duration(days: 7));
    }
    final months = [
      '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return '${next.day} ${months[next.month]} ${next.year} · $_timeLabel';
  }

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(KreditSpacing.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KreditSectionCard(
            label: 'RESPALDO AUTOMÁTICO',
            icon: Icons.backup_outlined,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: Icon(
                  Icons.cloud_sync_outlined,
                  color: _enabled ? accent : kredit.textTertiary,
                ),
                title: const Text('Activar respaldo automático'),
                subtitle: Text(
                  _enabled
                      ? 'Se respalda $_frequencyLabel automáticamente'
                      : 'Los respaldos manuales siguen disponibles',
                  style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
                ),
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
              ),
            ],
          ),
          const SizedBox(height: KreditSpacing.section),

          // Carpeta de destino (informativa)
          KreditSectionCard(
            label: 'CARPETA DE DESTINO',
            icon: Icons.folder_outlined,
            children: [
              Row(
                children: [
                  Icon(Icons.folder_open_outlined, size: KreditIconSize.small, color: kredit.textSecondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Almacenamiento principal del teléfono',
                          style: TextStyle(
                            fontSize: KreditTextSize.body,
                            fontWeight: FontWeight.w600,
                            color: kredit.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Kredit/backups/',
                          style: TextStyle(
                            fontSize: KreditTextSize.caption,
                            fontFamily: 'monospace',
                            color: kredit.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Al mismo nivel que Descargas y Documentos',
                          style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textTertiary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: KreditSpacing.section),

          if (_enabled) ...[
            KreditSectionCard(
              label: 'FRECUENCIA',
              icon: Icons.schedule_outlined,
              children: [
                _RadioOption(
                  value: 'daily',
                  groupValue: _frequency,
                  title: 'Diario',
                  subtitle: 'Un respaldo cada día',
                  onChanged: (v) => setState(() => _frequency = v!),
                ),
                _RadioOption(
                  value: 'weekly',
                  groupValue: _frequency,
                  title: 'Semanal',
                  subtitle: 'Un respaldo cada 7 días',
                  onChanged: (v) => setState(() => _frequency = v!),
                ),
                _RadioOption(
                  value: 'biweekly',
                  groupValue: _frequency,
                  title: 'Quincenal',
                  subtitle: 'Un respaldo cada 15 días',
                  onChanged: (v) => setState(() => _frequency = v!),
                ),
                _RadioOption(
                  value: 'monthly',
                  groupValue: _frequency,
                  title: 'Mensual',
                  subtitle: 'Un respaldo al mes',
                  onChanged: (v) => setState(() => _frequency = v!),
                ),
              ],
            ),
            const SizedBox(height: KreditSpacing.section),

            KreditSectionCard(
              label: 'HORA DEL RESPALDO',
              icon: Icons.access_time_outlined,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(KreditRadius.tile),
                    onTap: _pickTime,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      child: Row(
                        children: [
                          Icon(Icons.access_time_outlined,
                              size: KreditIconSize.small, color: kredit.textSecondary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _timeLabel,
                                  style: TextStyle(
                                    fontSize: KreditTextSize.emphasis,
                                    fontWeight: FontWeight.w700,
                                    color: kredit.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Toca para cambiar la hora',
                                  style: TextStyle(
                                      fontSize: KreditTextSize.caption,
                                      color: kredit.textTertiary),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.edit_outlined,
                              size: KreditIconSize.small, color: kredit.textTertiary),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: KreditSpacing.section),

            KreditSectionCard(
              label: 'MODO DE ARCHIVO',
              icon: Icons.storage_outlined,
              children: [
                _RadioOption(
                  value: 'overwrite',
                  groupValue: _mode,
                  title: 'Un solo archivo (sobreescribir)',
                  subtitle: 'Siempre el mismo archivo kredit_backup.json',
                  onChanged: (v) => setState(() => _mode = v!),
                ),
                _RadioOption(
                  value: 'new_file',
                  groupValue: _mode,
                  title: 'Archivo por respaldo',
                  subtitle: 'Crea kredit_backup_<fecha>.json en cada respaldo',
                  onChanged: (v) => setState(() => _mode = v!),
                ),
              ],
            ),
            const SizedBox(height: KreditSpacing.section),

            KreditSectionCard(
              label: 'PRÓXIMO RESPALDO',
              icon: Icons.event_outlined,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: KreditIconSize.small, color: kredit.textTertiary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nextBackupLabel,
                            style: TextStyle(
                              fontSize: KreditTextSize.heading,
                              fontWeight: FontWeight.w700,
                              color: kredit.textPrimary,
                            ),
                          ),
                          Text(
                            'Frecuencia: $_frequencyLabel · Modo: ${_mode == 'overwrite' ? 'Sobreescribir' : 'Archivo nuevo'}',
                            style: TextStyle(
                                fontSize: KreditTextSize.body, color: kredit.textTertiary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: KreditSpacing.section),
          ],

          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Guardar configuración'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
          ),
          const SizedBox(height: KreditSpacing.section),
        ],
      ),
    );
  }
}

class _RadioOption extends StatelessWidget {
  final String value;
  final String groupValue;
  final String title;
  final String subtitle;
  final ValueChanged<String?> onChanged;

  const _RadioOption({
    required this.value,
    required this.groupValue,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;
    final selected = value == groupValue;
    return InkWell(
      borderRadius: BorderRadius.circular(KreditRadius.tile),
      onTap: () => onChanged(value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.08) : kredit.bgCard,
          borderRadius: BorderRadius.circular(KreditRadius.tile),
          border: Border.all(
            color: selected ? accent.withValues(alpha: 0.5) : kredit.borderCard,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: KreditIconSize.small,
              color: selected ? accent : kredit.textTertiary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: KreditTextSize.body,
                      fontWeight: FontWeight.w600,
                      color: kredit.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
