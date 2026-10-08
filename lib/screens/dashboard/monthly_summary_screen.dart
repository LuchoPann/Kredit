import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/credit.dart';
import '../../domain/card_calculator.dart';
import '../../domain/date_utils.dart';
import '../../providers/credits_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/credit_display_utils.dart';

const _meses = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
];

class MonthlySummaryScreen extends ConsumerStatefulWidget {
  const MonthlySummaryScreen({super.key});

  @override
  ConsumerState<MonthlySummaryScreen> createState() => _MonthlySummaryScreenState();
}

class _MonthlySummaryScreenState extends ConsumerState<MonthlySummaryScreen> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
  }

  void _prevMonth() => setState(() {
        if (_month == 1) { _month = 12; _year--; }
        else { _month--; }
      });

  void _nextMonth() {
    final now = DateTime.now();
    final isCurrentOrFuture = _year > now.year || (_year == now.year && _month >= now.month);
    if (isCurrentOrFuture) return;
    setState(() {
      if (_month == 12) { _month = 1; _year++; }
      else { _month++; }
    });
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _year == now.year && _month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    final credits = ref.watch(creditsProvider).value ?? [];
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;

    final installmentRows = _buildInstallmentRows(credits);
    final cardRows = _buildCardRows(credits);
    final hasContent = installmentRows.isNotEmpty || cardRows.isNotEmpty;

    final totalProjectado = installmentRows.fold(0.0, (s, r) => s + r.amount) +
        cardRows.fold(0.0, (s, r) => s + r.amount);
    final totalPagado = installmentRows.where((r) => r.paid).fold(0.0, (s, r) => s + r.amount);
    final pendiente = totalProjectado - totalPagado;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estado de cuenta'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Month navigator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: kredit.bgCard,
                border: Border(bottom: BorderSide(color: kredit.borderCard)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _prevMonth,
                    color: kredit.textPrimary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Expanded(
                    child: Text(
                      '${_meses[_month - 1]} $_year',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: KreditTextSize.heading,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right, color: _isCurrentMonth ? kredit.textTertiary : kredit.textPrimary),
                    onPressed: _isCurrentMonth ? null : _nextMonth,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            Expanded(
              child: hasContent
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Resumen numérico
                        _SummaryHeader(
                          totalProjectado: totalProjectado,
                          totalPagado: totalPagado,
                          pendiente: pendiente,
                        ),
                        const SizedBox(height: 20),

                        // Cuotas de préstamos
                        if (installmentRows.isNotEmpty) ...[
                          _SectionTitle(label: 'CUOTAS DE PRÉSTAMOS', count: installmentRows.length),
                          const SizedBox(height: 8),
                          ...installmentRows.map((r) => _InstallmentTile(row: r, accent: accent)),
                          const SizedBox(height: 20),
                        ],

                        // Tarjetas
                        if (cardRows.isNotEmpty) ...[
                          _SectionTitle(label: 'TARJETAS DE CRÉDITO', count: cardRows.length),
                          const SizedBox(height: 8),
                          ...cardRows.map((r) => _CardTile(row: r, accent: accent)),
                        ],
                      ],
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_available_outlined, size: KreditIconSize.large, color: kredit.textTertiary),
                          const SizedBox(height: 12),
                          Text(
                            'Sin vencimientos en este mes.',
                            style: TextStyle(color: kredit.textSecondary, fontSize: KreditTextSize.body),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<_InstallmentRow> _buildInstallmentRows(List<Credit> credits) {
    final today = DateTime.now();
    final rows = <_InstallmentRow>[];
    for (final c in credits) {
      if (c is! LoanCredit) continue;
      for (final inst in c.installments) {
        final due = parseDateStr(inst.dueDate);
        if (due.year == _year && due.month == _month) {
          final overdue = !inst.paid && due.isBefore(DateTime(today.year, today.month, today.day));
          rows.add(_InstallmentRow(
            creditName: c.name,
            amount: inst.amount,
            dueDate: due,
            paid: inst.paid,
            overdue: overdue,
          ));
        }
      }
    }
    rows.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return rows;
  }

  List<_CardRow> _buildCardRows(List<Credit> credits) {
    final rows = <_CardRow>[];
    for (final c in credits) {
      if (c is! CardCredit) continue;
      if (c.currentBalance <= 0) continue;
      final dates = getCardCycleDates(c);
      final due = dates.dueDate;
      if (due.year == _year && due.month == _month) {
        final usage = c.creditLimit > 0 ? (c.currentBalance / c.creditLimit).clamp(0.0, 1.0) : 0.0;
        rows.add(_CardRow(
          creditName: c.name,
          amount: c.currentBalance,
          dueDate: due,
          usagePct: usage,
          creditLimit: c.creditLimit,
        ));
      }
    }
    return rows;
  }
}

class _InstallmentRow {
  final String creditName;
  final double amount;
  final DateTime dueDate;
  final bool paid;
  final bool overdue;
  const _InstallmentRow({
    required this.creditName,
    required this.amount,
    required this.dueDate,
    required this.paid,
    required this.overdue,
  });
}

class _CardRow {
  final String creditName;
  final double amount;
  final DateTime dueDate;
  final double usagePct;
  final double creditLimit;
  const _CardRow({
    required this.creditName,
    required this.amount,
    required this.dueDate,
    required this.usagePct,
    required this.creditLimit,
  });
}

class _SummaryHeader extends StatelessWidget {
  final double totalProjectado;
  final double totalPagado;
  final double pendiente;

  const _SummaryHeader({
    required this.totalProjectado,
    required this.totalPagado,
    required this.pendiente,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final allPaid = pendiente <= 0 && totalProjectado > 0;

    return Container(
      padding: const EdgeInsets.all(KreditSpacing.card),
      decoration: BoxDecoration(
        color: kredit.bgCard,
        borderRadius: BorderRadius.circular(KreditRadius.card),
        border: Border.all(color: kredit.borderCard),
      ),
      child: Row(
        children: [
          _SummaryCell(label: 'PROYECTADO', value: formatCOP(totalProjectado), color: kredit.textPrimary),
          _Divider(),
          _SummaryCell(label: 'PAGADO', value: formatCOP(totalPagado), color: kredit.success),
          _Divider(),
          _SummaryCell(
            label: allPaid ? 'COMPLETADO' : 'PENDIENTE',
            value: formatCOP(pendiente < 0 ? 0 : pendiente),
            color: allPaid ? kredit.success : kredit.warning,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Container(width: 1, height: 36, margin: const EdgeInsets.symmetric(horizontal: 12), color: kredit.borderCard);
  }
}

class _SummaryCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryCell({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: KreditTextSize.body, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: kredit.textTertiary)),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(fontSize: KreditTextSize.body, fontWeight: FontWeight.w800, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  final int count;

  const _SectionTitle({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Row(
      children: [
        Text(label, style: TextStyle(fontSize: KreditTextSize.body, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: kredit.textTertiary)),
        const SizedBox(width: 6),
        Text('$count', style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary)),
      ],
    );
  }
}

class _InstallmentTile extends StatelessWidget {
  final _InstallmentRow row;
  final Color accent;

  const _InstallmentTile({required this.row, required this.accent});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final IconData icon;
    final Color iconColor;
    if (row.paid) {
      icon = Icons.check_circle;
      iconColor = kredit.success;
    } else if (row.overdue) {
      icon = Icons.cancel;
      iconColor = kredit.danger;
    } else {
      icon = Icons.radio_button_unchecked;
      iconColor = kredit.textTertiary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kredit.bgCard,
        borderRadius: BorderRadius.circular(KreditRadius.tile),
        border: Border.all(color: row.overdue && !row.paid ? kredit.danger.withValues(alpha: 0.4) : kredit.borderCard),
      ),
      child: Row(
        children: [
          Icon(icon, size: KreditIconSize.small, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.creditName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: KreditTextSize.body, color: kredit.textPrimary)),
                Text(
                  'Vence ${toDateStr(row.dueDate)}',
                  style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
                ),
              ],
            ),
          ),
          Text(formatCOP(row.amount), style: TextStyle(fontWeight: FontWeight.w700, fontSize: KreditTextSize.body, color: kredit.textPrimary)),
        ],
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  final _CardRow row;
  final Color accent;

  const _CardTile({required this.row, required this.accent});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final usageColor = row.usagePct >= 0.85 ? kredit.danger : (row.usagePct >= 0.65 ? kredit.warning : accent);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kredit.bgCard,
        borderRadius: BorderRadius.circular(KreditRadius.tile),
        border: Border.all(color: kredit.borderCard),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.credit_card_outlined, size: KreditIconSize.small, color: kredit.textTertiary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(row.creditName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: KreditTextSize.body, color: kredit.textPrimary)),
                    Text('Vence ${toDateStr(row.dueDate)}', style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary)),
                  ],
                ),
              ),
              Text(formatCOP(row.amount), style: TextStyle(fontWeight: FontWeight.w700, fontSize: KreditTextSize.body, color: kredit.textPrimary)),
            ],
          ),
          if (row.creditLimit > 0) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: row.usagePct,
                minHeight: 4,
                backgroundColor: kredit.borderCard,
                valueColor: AlwaysStoppedAnimation<Color>(usageColor),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Usas el ${(row.usagePct * 100).round()}% del cupo de ${formatCOP(row.creditLimit)}',
              style: TextStyle(fontSize: KreditTextSize.body, color: kredit.textTertiary),
            ),
          ],
        ],
      ),
    );
  }
}
