import 'package:flutter/material.dart';

import '../../domain/loan_calculator.dart';
import '../../theme/app_theme.dart';

/// Compact status indicator for an installment — plain icon + text, no
/// surrounding chip/border. Uses theme-aware colors: the accent for
/// paid/overdue/warning states (so it reads consistently against both light
/// and dark surfaces) and textTertiary for plain "pending" — avoids the
/// fixed AppColors.success/danger which don't adapt per-theme.
class StatusBadge extends StatelessWidget {
  final InstallmentStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    Color color;
    IconData icon;
    switch (status.state) {
      case InstallmentState.paid:
        color = kredit.success;
        icon = Icons.check_circle_rounded;
        break;
      case InstallmentState.overdue:
        color = kredit.danger;
        icon = Icons.error_outline_rounded;
        break;
      case InstallmentState.warning:
        color = kredit.warning;
        icon = Icons.schedule_rounded;
        break;
      case InstallmentState.pending:
        color = kredit.textTertiary;
        icon = Icons.circle_outlined;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(KreditRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: KreditIconSize.small, color: color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: KreditTextSize.caption,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
