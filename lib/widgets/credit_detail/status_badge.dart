import 'package:flutter/material.dart';

import '../../domain/loan_calculator.dart';
import '../../theme/app_theme.dart';

/// Compact status pill for an installment. Uses theme-aware colors: the
/// accent for paid/overdue/warning states (so it reads consistently against
/// both light and dark surfaces) and textTertiary for plain "pending" —
/// avoids the fixed AppColors.success/danger which don't adapt per-theme.
class StatusBadge extends StatelessWidget {
  final InstallmentStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;
    Color color;
    IconData icon;
    switch (status.state) {
      case InstallmentState.paid:
        color = accent;
        icon = Icons.check_circle;
        break;
      case InstallmentState.overdue:
        color = kredit.textPrimary;
        icon = Icons.error_outline;
        break;
      case InstallmentState.warning:
        color = kredit.textPrimary;
        icon = Icons.schedule;
        break;
      case InstallmentState.pending:
        color = kredit.textTertiary;
        icon = Icons.circle_outlined;
        break;
    }
    final filled = status.state == InstallmentState.overdue ||
        status.state == InstallmentState.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color.withValues(alpha: 0.15) : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(KreditRadius.chip),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(status.label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
