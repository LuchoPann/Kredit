import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/credit.dart';
import '../../providers/credits_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/credit_detail/movements_tab.dart';
import '../../widgets/credit_detail/schedule_tab.dart';
import '../../widgets/credit_detail/summary_tab.dart';
import '../../widgets/demo_badge.dart';
import 'edit_credit_sheet.dart';

/// Detail screen for a single credit, with 2 tabs mirroring
/// #view-credit-detail in legacy_pwa/index.html (~L340-489): Resumen (which
/// embeds the former Notas content at the bottom via `NotesTab`) and
/// Cronograma (loan) / Movimientos (card).
///
/// Route: pushed via `Navigator.pushNamed(context, '/credit-detail', arguments: creditId)`
/// — reads the credit id from `ModalRoute.of(context)!.settings.arguments as String`.
class CreditDetailScreen extends ConsumerStatefulWidget {
  final String creditId;

  const CreditDetailScreen({super.key, required this.creditId});

  @override
  ConsumerState<CreditDetailScreen> createState() => _CreditDetailScreenState();
}

class _CreditDetailScreenState extends ConsumerState<CreditDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(BuildContext context, Credit credit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Crédito'),
        content: Text(
          '¿Eliminar "${credit.name}" y todo su historial? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(creditsProvider.notifier).deleteCredit(credit.id);
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('"${credit.name}" eliminado')));
      }
    } catch (e) {
      debugPrint('deleteCredit failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar el crédito. Intenta de nuevo.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final creditsAsync = ref.watch(creditsProvider);

    return creditsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (credits) {
        final credit = credits
            .where((c) => c.id == widget.creditId)
            .firstOrNull;
        if (credit == null) {
          return const Scaffold(
            body: Center(child: Text('Crédito no encontrado')),
          );
        }
        final isLoan = credit is LoanCredit;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(credit.name, overflow: TextOverflow.ellipsis),
                ),
                if (isDemoCredit(credit.id)) const DemoBadge(),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight + 34),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _CreditTypeBadge(isLoan: isLoan),
                  ),
                  TabBar(
                    controller: _tabController,
                    tabs: [
                      const Tab(text: 'Resumen'),
                      Tab(text: isLoan ? 'Cronograma' : 'Movimientos'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              SummaryTab(credit: credit),
              if (credit case LoanCredit loan)
                ScheduleTab(credit: loan)
              else
                MovementsTab(credit: credit as CardCredit),
            ],
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => EditCreditSheet.show(context, credit),
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar Crédito'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                    ),
                    onPressed: () => _confirmDelete(context, credit),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Eliminar'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Small chip identifying whether this credit is a "Préstamo" or a "Tarjeta
/// de Crédito" — shown right below the AppBar title, before the tabs, since
/// the tab labels alone ("Cronograma" vs "Movimientos") aren't an obvious
/// enough signal on their own. Visual language matches `StatusBadge`
/// (icon + text over a soft tinted pill).
class _CreditTypeBadge extends StatelessWidget {
  final bool isLoan;
  const _CreditTypeBadge({required this.isLoan});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final icon = isLoan
        ? Icons.request_quote_outlined
        : Icons.credit_card_outlined;
    final label = isLoan ? 'Préstamo' : 'Tarjeta de Crédito';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(KreditRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
