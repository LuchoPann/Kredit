import 'package:flutter/material.dart';

import '../screens/stats/attack_plan_screen.dart';
import '../screens/stats/calculator_sheet.dart';
import '../screens/stats/credit_comparison_screen.dart';
import '../screens/stats/payment_goals_screen.dart';
import '../screens/stats/spending_breakdown_screen.dart';
import '../screens/stats/strategy_comparison_screen.dart';
import '../theme/app_theme.dart';

void showAttackToolsSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _AttackToolsSheet(),
  );
}

class _AttackToolsSheet extends StatelessWidget {
  const _AttackToolsSheet();

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<AppThemeColors>()!;
    final accent = Theme.of(context).colorScheme.primary;

    void go(Widget screen) {
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    }

    void goSheet(Widget sheet) {
      Navigator.pop(context);
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => sheet,
      );
    }

    final tools = [
      _Tool(
        icon: Icons.calculate_outlined,
        iconColor: kredit.textSecondary,
        title: 'Calcular cuota',
        subtitle: 'Simula el pago mensual de un crédito nuevo',
        onTap: () => goSheet(const CalculatorSheet()),
      ),
      _Tool(
        icon: Icons.bolt_rounded,
        iconColor: accent,
        title: 'Plan de ataque',
        subtitle: 'Snowball o Avalanche con pago extra',
        onTap: () => go(const AttackPlanScreen()),
      ),
      _Tool(
        icon: Icons.show_chart_rounded,
        iconColor: kredit.success,
        title: 'Comparar estrategias',
        subtitle: 'Mínimos vs Snowball vs Avalanche en una gráfica',
        onTap: () => go(const StrategyComparisonScreen()),
      ),
      _Tool(
        icon: Icons.compare_arrows_rounded,
        iconColor: Theme.of(context).colorScheme.tertiary,
        title: 'Comparar créditos',
        subtitle: 'Analiza dos créditos lado a lado',
        onTap: () => go(const CreditComparisonScreen()),
      ),
      _Tool(
        icon: Icons.flag_rounded,
        iconColor: kredit.warning,
        title: 'Metas de pago',
        subtitle: 'Trackea objetivos de reducción de deuda',
        onTap: () => go(const PaymentGoalsScreen()),
      ),
      _Tool(
        icon: Icons.pie_chart_outline_rounded,
        iconColor: const Color(0xFFF97316),
        title: 'Gastos por categoría',
        subtitle: 'Distribución de cargos en tus tarjetas',
        onTap: () => go(const SpendingBreakdownScreen()),
      ),
    ];

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: kredit.textTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Icon(Icons.bolt_rounded, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Herramientas de ataque',
                      style: TextStyle(
                        fontSize: AppTextSize.heading,
                        fontWeight: FontWeight.w700,
                        color: kredit.textPrimary,
                      ),
                    ),
                    Text(
                      'Estrategias para liquidar tu deuda',
                      style: TextStyle(fontSize: AppTextSize.body, color: kredit.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Tool list
          for (int i = 0; i < tools.length; i++) ...[
            _ToolTile(tool: tools[i], kredit: kredit),
            if (i < tools.length - 1) Divider(height: 1, color: kredit.borderCard),
          ],
        ],
      ),
    );
  }
}

class _Tool {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _Tool({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

class _ToolTile extends StatelessWidget {
  final _Tool tool;
  final AppThemeColors kredit;

  const _ToolTile({required this.tool, required this.kredit});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: tool.iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(tool.icon, size: AppIconSize.small, color: tool.iconColor),
        ),
        title: Text(
          tool.title,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: AppTextSize.body, color: kredit.textPrimary),
        ),
        subtitle: Text(
          tool.subtitle,
          style: TextStyle(fontSize: AppTextSize.caption, color: kredit.textSecondary),
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: kredit.textTertiary),
        onTap: tool.onTap,
      ),
    );
  }
}
