import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/commercial_quota.dart';
import '../../data/models/credit.dart';
import '../../providers/commercial_quotas_provider.dart';
import '../../providers/credits_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/account/voucher_pattern_picker.dart';
import '../../widgets/voucher_pattern.dart';
import '../../widgets/credit_detail/movements_tab.dart';
import '../../widgets/credit_detail/quota_group_tabs.dart';
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
  // Qué compra del cupo está abierta en el acordeón — una sola fuente de
  // verdad compartida por Resumen y Cronograma, para que cambiar de
  // pestaña nunca "pierda" cuál compra se estaba revisando.
  String? _expandedPurchaseId;

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

  /// Opens the voucher-design picker for THIS specific cupo — each cupo
  /// comercial carries its own [CommercialQuota.voucherPattern], separate
  /// from every other cupo's, so picking a style here only ever changes
  /// this voucher's own vouchers.
  void _showVoucherPatternPicker(BuildContext context, CommercialQuota quota) {
    final accent = Theme.of(context).colorScheme.primary;
    // StatefulBuilder gives the bottom sheet its own setState so VoucherPatternPicker
    // rebuilds immediately when the user taps a design (provider update alone is not
    // enough — the builder closure captures quota.voucherPattern at open time and
    // never re-evaluates it without local state driving a rebuild).
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        var current = VoucherPattern.fromName(quota.voucherPattern);
        return StatefulBuilder(
          builder: (ctx, setModalState) => Padding(
            padding: EdgeInsets.only(
              left: KreditSpacing.card,
              right: KreditSpacing.card,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + KreditSpacing.card,
            ),
            child: SingleChildScrollView(
              child: VoucherPatternPicker(
                selected: current,
                accent: accent,
                onSelect: (pattern) {
                  setModalState(() => current = pattern);
                  ref.read(commercialQuotasProvider.notifier).upsert(
                    CommercialQuota(
                      id: quota.id,
                      brand: quota.brand,
                      limit: quota.limit,
                      notes: quota.notes,
                      voucherPattern: pattern.name,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  /// Extracts the millisecond timestamp `_save()` encodes into every
  /// credit's id (`credit_<millis>`), for sorting purchases most-recent
  /// first. Falls back to 0 for ids that don't match (seeded demo credits).
  int _idTimestamp(String id) {
    final match = RegExp(r'credit_(\d+)').firstMatch(id);
    return match == null ? 0 : int.parse(match.group(1)!);
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

        // A LoanCredit tagged with a CommercialQuota (Totto, Lili Pink,
        // Éxito CrediCompras...) opens grouped with every other purchase
        // under that same cupo — the user came in through one purchase,
        // but sees the whole cupo from here, entering purchase first.
        final quotaId = credit is LoanCredit ? credit.quotaId : null;
        List<LoanCredit>? groupPurchases;
        CommercialQuota? quota;
        if (quotaId != null) {
          groupPurchases = credits
              .whereType<LoanCredit>()
              .where((c) => c.quotaId == quotaId)
              .toList()
            ..sort((a, b) => _idTimestamp(b.id).compareTo(_idTimestamp(a.id)));
          groupPurchases
              .removeWhere((c) => c.id == credit.id);
          groupPurchases.insert(0, credit as LoanCredit);
          final quotas = ref.watch(commercialQuotasProvider).valueOrNull ?? const [];
          for (final q in quotas) {
            if (q.id == quotaId) {
              quota = q;
              break;
            }
          }
        }
        final isGrouped = groupPurchases != null;
        // La compra que trajo al usuario a este detalle empieza abierta;
        // se ejecuta en cada build pero solo asigna una vez (??=).
        if (isGrouped) {
          _expandedPurchaseId ??= groupPurchases.first.id;
        }

        return Scaffold(
          appBar: AppBar(
            // Entidad + etiqueta de tipo (Préstamo/Tarjeta) comparten la
            // fila superior junto a la flecha de regreso y el botón de
            // diseño de voucher — antes la etiqueta vivía en su propia
            // fila sobre las pestañas, robándole alto a Resumen/Cronograma.
            centerTitle: true,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    isGrouped ? (quota?.brand ?? credit.lender) : credit.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _CreditTypeBadge(isLoan: isLoan),
                if (isDemoCredit(credit.id)) const DemoBadge(),
              ],
            ),
            // Un solo botón de eliminar visible en toda la pantalla: el
            // rojo junto a cada compra expandida. Eliminar el cupo entero
            // ya no vive en un botón separado aquí — se ofrece
            // automáticamente al vaciarlo (ver credits_list_screen).
            actions: [
              if (isGrouped && quota != null)
                IconButton(
                  onPressed: () => _showVoucherPatternPicker(context, quota!),
                  icon: const Icon(Icons.palette_outlined),
                  tooltip: 'Diseño de voucher',
                ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                const Tab(text: 'Resumen'),
                Tab(text: isLoan ? 'Cronograma' : 'Movimientos'),
              ],
            ),
          ),
          body: isGrouped
              ? TabBarView(
                  controller: _tabController,
                  children: [
                    QuotaGroupSummaryTab(
                      quota: quota,
                      purchases: groupPurchases,
                      expandedId: _expandedPurchaseId,
                      onToggle: (id) => setState(
                        () => _expandedPurchaseId =
                            _expandedPurchaseId == id ? null : id,
                      ),
                    ),
                    QuotaGroupScheduleTab(
                      purchases: groupPurchases,
                      expandedId: _expandedPurchaseId,
                      onToggle: (id) => setState(
                        () => _expandedPurchaseId =
                            _expandedPurchaseId == id ? null : id,
                      ),
                    ),
                  ],
                )
              : TabBarView(
            controller: _tabController,
            children: [
              SummaryTab(credit: credit),
              if (credit case LoanCredit loan)
                ScheduleTab(credit: loan)
              else
                MovementsTab(credit: credit as CardCredit),
            ],
          ),
          // Cuando está agrupado, editar/eliminar viven junto a cada
          // voucher dentro del Resumen (ambiguo cuál compra afectaría un
          // botón global aquí) — "Eliminar cupo" ya está en el AppBar.
          bottomNavigationBar: isGrouped
              ? null
              : Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => EditCreditSheet.show(context, credit),
                          icon: const Icon(Icons.edit_outlined),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(KreditRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
