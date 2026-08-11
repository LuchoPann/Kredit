import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/credit.dart';
import '../../data/models/installment.dart';
import '../../domain/date_utils.dart';
import '../../domain/loan_calculator.dart';
import '../../providers/credits_provider.dart';
import '../../theme/app_theme.dart';
import '../wallet_card.dart';
import 'status_badge.dart';

/// Cronograma de cuotas, grouped by urgency instead of a flat chronological
/// list — with many installments a plain list becomes a monotonous scroll
/// where the handful of cuotas that actually need attention (overdue / due
/// soon) get buried among dozens of future ones. Grouping into
/// Vencidas → Próximas → Futuras → Pagadas lets a user answer "am I behind"
/// in one glance, and the paid section collapses by default since it's
/// historical record, not something to act on.
class ScheduleTab extends ConsumerStatefulWidget {
  final LoanCredit credit;

  const ScheduleTab({super.key, required this.credit});

  @override
  ConsumerState<ScheduleTab> createState() => _ScheduleTabState();
}

double _sumAmount(List<Installment> insts) =>
    insts.fold(0.0, (s, i) => s + i.amount);

class _ScheduleTabState extends ConsumerState<ScheduleTab> {
  bool _paidExpanded = false;

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final credit = widget.credit;
    final unpaidCount = credit.installments.where((i) => !i.paid).length;

    final overdue = <Installment>[];
    final dueSoon = <Installment>[];
    final upcoming = <Installment>[];
    final paid = <Installment>[];
    for (final inst in credit.installments) {
      if (inst.paid) {
        paid.add(inst);
        continue;
      }
      final state = getInstallmentStatus(inst).state;
      if (state == InstallmentState.overdue) {
        overdue.add(inst);
      } else if (state == InstallmentState.warning) {
        dueSoon.add(inst);
      } else {
        upcoming.add(inst);
      }
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Text('Cronograma de Cuotas ($unpaidCount)',
                  style: TextStyle(fontWeight: FontWeight.w700, color: kredit.textPrimary)),
              const Spacer(),
              TextButton.icon(
                onPressed: unpaidCount == 0
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final count = unpaidCount;
                        try {
                          await ref
                              .read(creditsProvider.notifier)
                              .markAllInstallmentsPaid(credit.id);
                          messenger.showSnackBar(
                            SnackBar(content: Text('$count cuota(s) registradas como pagadas')),
                          );
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('No se pudo registrar el pago total: $e')),
                          );
                        }
                      },
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Registrar pago total'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              if (overdue.isNotEmpty)
                _SectionGroup(
                  title: 'Vencidas',
                  count: overdue.length,
                  total: _sumAmount(overdue),
                  emphasized: true,
                  children: overdue.map((i) => _InstallmentTile(credit: credit, inst: i)).toList(),
                ),
              if (dueSoon.isNotEmpty)
                _SectionGroup(
                  title: 'Próximas',
                  count: dueSoon.length,
                  total: _sumAmount(dueSoon),
                  children: dueSoon.map((i) => _InstallmentTile(credit: credit, inst: i)).toList(),
                ),
              if (upcoming.isNotEmpty)
                _SectionGroup(
                  title: 'Futuras',
                  count: upcoming.length,
                  total: _sumAmount(upcoming),
                  children: upcoming.map((i) => _InstallmentTile(credit: credit, inst: i)).toList(),
                ),
              if (paid.isNotEmpty)
                _SectionGroup(
                  title: 'Pagadas',
                  count: paid.length,
                  total: _sumAmount(paid),
                  collapsible: true,
                  expanded: _paidExpanded,
                  onToggle: () => setState(() => _paidExpanded = !_paidExpanded),
                  children: paid.map((i) => _InstallmentTile(credit: credit, inst: i)).toList(),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionGroup extends StatelessWidget {
  final String title;
  final int count;
  final double total;
  final List<Widget> children;
  final bool emphasized;
  final bool collapsible;
  final bool expanded;
  final VoidCallback? onToggle;

  const _SectionGroup({
    required this.title,
    required this.count,
    required this.total,
    required this.children,
    this.emphasized = false,
    this.collapsible = false,
    this.expanded = false,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final showChildren = !collapsible || expanded;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: collapsible ? onToggle : null,
            borderRadius: BorderRadius.circular(KreditRadius.chip),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: emphasized ? kredit.textPrimary : kredit.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: kredit.bgSecondary,
                      borderRadius: BorderRadius.circular(KreditRadius.chip),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kredit.textSecondary),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formatCurrency(total),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: emphasized ? kredit.textPrimary : kredit.textSecondary,
                    ),
                  ),
                  if (collapsible) ...[
                    const SizedBox(width: 6),
                    Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: kredit.textTertiary,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (showChildren) ...children,
        ],
      ),
    );
  }
}

class _InstallmentTile extends ConsumerWidget {
  final LoanCredit credit;
  final Installment inst;

  const _InstallmentTile({required this.credit, required this.inst});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final status = getInstallmentStatus(inst);
    final accent = Theme.of(context).colorScheme.primary;
    final onAccent = accent.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            ref.read(creditsProvider.notifier).toggleInstallmentPaid(credit.id, inst.number),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: inst.paid ? accent : Colors.transparent,
                  border: Border.all(
                    color: inst.paid ? accent : kredit.textTertiary,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(KreditRadius.chip),
                ),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: inst.paid ? 1 : 0,
                  child: Icon(Icons.check, size: 16, color: onAccent),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cuota ${inst.number} — ${formatCurrency(inst.amount)}',
                        style: TextStyle(color: kredit.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Vence: ${formatDate(inst.dueDate)}',
                        style: TextStyle(fontSize: 12, color: kredit.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              StatusBadge(status: status),
            ],
          ),
        ),
      ),
    );
  }
}
