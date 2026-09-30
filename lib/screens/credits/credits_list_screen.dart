import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart' show QuotaHasActivePurchasesException;
import '../../data/models/credit.dart';
import '../../domain/bank_detector.dart';
import '../../domain/credit_calculator.dart';
import '../../domain/urgency_score.dart';
import '../../data/models/commercial_quota.dart';
import '../../providers/commercial_quotas_provider.dart';
import '../../providers/credits_filter_provider.dart';
import '../../providers/credits_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/credit_display_utils.dart';
import '../../widgets/credits/commercial_quota_card.dart';
import '../../widgets/wallet_card.dart';

/// Full credits list ("Créditos") screen — ported from `#view-credits` in
/// legacy_pwa/index.html (~L188-219): search box, sort dropdown,
/// Activos/Pagados tabs, and the credits list itself.
class CreditsListScreen extends ConsumerWidget {
  const CreditsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creditsAsync = ref.watch(creditsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Créditos')),
      body: creditsAsync.when(
        loading: () => const _LoadingState(),
        error: (err, st) => _ErrorState(
          message: 'No se pudieron cargar los créditos.',
          onRetry: () => ref.invalidate(creditsProvider),
        ),
        data: (credits) => _CreditsListBody(credits: credits),
      ),
      floatingActionButton: Builder(
        builder: (context) {
          final accentColor = Theme.of(context).colorScheme.primary;
          final fgColor = legibleForegroundOn(accentColor);
          return FloatingActionButton(
            // Distinct from dashboard_screen.dart's FAB — see the comment
            // there for why this matters now that IndexedStack keeps every
            // tab mounted at once.
            heroTag: 'fab-credits',
            backgroundColor: accentColor,
            foregroundColor: fgColor,
            onPressed: () => Navigator.of(context).pushNamed('/add-credit'),
            tooltip: 'Agregar Crédito',
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
}

/// Branded loading spinner — thinner stroke + accent color, consistent
/// across all list/detail loading states in this screen's area.
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// Error placeholder with icon + message + retry action, so failures read
/// as part of the design instead of raw debug text.
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: KreditIconSize.large, color: kredit.textTertiary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textSecondary),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: KreditIconSize.small),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreditsListBody extends ConsumerStatefulWidget {
  final List<Credit> credits;
  const _CreditsListBody({required this.credits});

  @override
  ConsumerState<_CreditsListBody> createState() => _CreditsListBodyState();
}

class _CreditsListBodyState extends ConsumerState<_CreditsListBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final filter = ref.watch(creditsFilterProvider);
    final active = widget.credits.where(creditHasUnpaid).toList();
    final completed = widget.credits.where((c) => !creditHasUnpaid(c)).toList();

    // Search + sort share one row (sort collapsed into an icon menu) instead
    // of stacking a full "Ordenar por:" row underneath — that alone used to
    // cost ~40px of vertical space competing with the tabs/list below for
    // room on smaller screens.
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar crédito, banco...',
                    hintStyle: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textTertiary),
                    prefixIcon: Icon(Icons.search, size: KreditIconSize.small, color: kredit.textSecondary),
                    suffixIcon: filter.query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: KreditIconSize.small),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(creditsFilterProvider.notifier).setQuery('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: kredit.bgCard,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    // Same radius family as the dashboard's section cards
                    // (_DashboardSectionCard, 20) and a near-invisible
                    // border instead of a solid one — reads as one soft
                    // surface, not a distinct boxed form control.
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: kredit.borderCard.withValues(alpha: 0.6)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: kredit.borderCard.withValues(alpha: 0.6)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                    ),
                    isDense: true,
                  ),
                  onChanged: (v) => ref.read(creditsFilterProvider.notifier).setQuery(v),
                ),
              ),
              const SizedBox(width: 8),
              // Same soft-surface language as the search field (bgCard +
              // faint border, matching radius) so the sort control reads as
              // part of the same row instead of a bare icon floating next
              // to a boxed field.
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: kredit.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kredit.borderCard.withValues(alpha: 0.6)),
                ),
                child: PopupMenuButton<CreditsSortOption>(
                  tooltip: 'Ordenar por',
                  icon: Icon(Icons.sort, color: kredit.textSecondary, size: KreditIconSize.small),
                  color: kredit.bgCard,
                  initialValue: filter.sort,
                  onSelected: (v) => ref.read(creditsFilterProvider.notifier).setSort(v),
                  itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: CreditsSortOption.urgency,
                        child: Text('Mayor urgencia'),
                      ),
                      PopupMenuItem(
                        value: CreditsSortOption.dueDate,
                        child: Text('Próximo Pago'),
                      ),
                      PopupMenuItem(
                        value: CreditsSortOption.debtDesc,
                        child: Text('Mayor Deuda'),
                      ),
                      PopupMenuItem(
                        value: CreditsSortOption.debtAsc,
                        child: Text('Menor Deuda'),
                      ),
                      PopupMenuItem(
                        value: CreditsSortOption.entity,
                        child: Text('Entidad A-Z'),
                      ),
                      PopupMenuItem(
                        value: CreditsSortOption.name,
                        child: Text('Nombre A-Z'),
                      ),
                    ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _QuickFilterBar(filter: filter),
        const SizedBox(height: 8),
        TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.label,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: KreditTextSize.body),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: KreditTextSize.body),
          unselectedLabelColor: kredit.textTertiary,
          tabs: [
            Tab(text: 'Activos (${active.length})'),
            Tab(text: 'Finalizados (${completed.length})'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _FilteredList(
                credits: active,
                filter: filter,
                emptyText: 'No tienes créditos activos.',
                showCommercialQuotas: true,
              ),
              _FilteredList(credits: completed, filter: filter, emptyText: 'No tienes créditos finalizados.'),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickFilterBar extends ConsumerWidget {
  final CreditsFilterState filter;

  const _QuickFilterBar({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _QuickFilterChip(
            label: 'Todos',
            selected: filter.quickFilter == CreditsQuickFilter.all,
            onTap: () => ref
                .read(creditsFilterProvider.notifier)
                .setQuickFilter(CreditsQuickFilter.all),
          ),
          _QuickFilterChip(
            label: 'Vencidos',
            selected: filter.quickFilter == CreditsQuickFilter.overdue,
            onTap: () => ref
                .read(creditsFilterProvider.notifier)
                .setQuickFilter(CreditsQuickFilter.overdue),
          ),
          _QuickFilterChip(
            label: 'Próximos',
            selected: filter.quickFilter == CreditsQuickFilter.upcoming,
            onTap: () => ref
                .read(creditsFilterProvider.notifier)
                .setQuickFilter(CreditsQuickFilter.upcoming),
          ),
          _QuickFilterChip(
            label: 'Tarjetas',
            selected: filter.quickFilter == CreditsQuickFilter.cards,
            onTap: () => ref
                .read(creditsFilterProvider.notifier)
                .setQuickFilter(CreditsQuickFilter.cards),
          ),
          _QuickFilterChip(
            label: 'Préstamos',
            selected: filter.quickFilter == CreditsQuickFilter.loans,
            onTap: () => ref
                .read(creditsFilterProvider.notifier)
                .setQuickFilter(CreditsQuickFilter.loans),
          ),
        ],
      ),
    );
  }
}

class _QuickFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _QuickFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        labelStyle: TextStyle(
          fontSize: KreditTextSize.caption,
          fontWeight: FontWeight.w700,
          color: selected ? legibleForegroundOn(accent) : kredit.textSecondary,
        ),
        selectedColor: accent,
        backgroundColor: kredit.bgCard,
        side: BorderSide(
          color: selected ? accent : kredit.borderCard.withValues(alpha: 0.7),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KreditRadius.chip),
        ),
      ),
    );
  }
}

class _FilteredList extends ConsumerWidget {
  final List<Credit> credits;
  final CreditsFilterState filter;
  final String emptyText;
  // Cupo comercial cards only belong to the Activos tab — a paid-off
  // purchase can still be linked to its quota (unlinking only happens when
  // the quota itself is deleted), so without this the same card would
  // duplicate into Finalizados too.
  final bool showCommercialQuotas;

  const _FilteredList({
    required this.credits,
    required this.filter,
    required this.emptyText,
    this.showCommercialQuotas = false,
  });

  List<Credit> _apply() {
    var result = credits;
    final query = filter.query.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((c) {
        final bank = detectBank(
          lender: c.lender,
          card: c is LoanCredit ? c.card : null,
        );
        final haystack = [
          c.name,
          c.lender,
          bank.shortLabel,
          if (c is LoanCredit) ...[c.location ?? '', c.card ?? ''],
        ].join(' ').toLowerCase();
        return haystack.contains(query);
      }).toList();
    }

    result = result.where(_matchesQuickFilter).toList();

    final sorted = [...result];
    switch (filter.sort) {
      case CreditsSortOption.urgency:
        sorted.sort((a, b) => _creditUrgency(b).compareTo(_creditUrgency(a)));
        break;
      case CreditsSortOption.dueDate:
        sorted.sort((a, b) {
          final da = getNextDueDate(a);
          final db = getNextDueDate(b);
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        });
        break;
      case CreditsSortOption.debtDesc:
        sorted.sort((a, b) =>
            getCreditRemainingBalance(b).compareTo(getCreditRemainingBalance(a)));
        break;
      case CreditsSortOption.debtAsc:
        sorted.sort((a, b) =>
            getCreditRemainingBalance(a).compareTo(getCreditRemainingBalance(b)));
        break;
      case CreditsSortOption.entity:
        sorted.sort((a, b) {
          final bankA = detectBank(
            lender: a.lender,
            card: a is LoanCredit ? a.card : null,
          ).shortLabel;
          final bankB = detectBank(
            lender: b.lender,
            card: b is LoanCredit ? b.card : null,
          ).shortLabel;
          final bankCompare = bankA.toLowerCase().compareTo(bankB.toLowerCase());
          if (bankCompare != 0) return bankCompare;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        break;
      case CreditsSortOption.name:
        sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
    }
    return sorted;
  }

  bool _matchesQuickFilter(Credit credit) {
    switch (filter.quickFilter) {
      case CreditsQuickFilter.all:
        return true;
      case CreditsQuickFilter.overdue:
        final next = getNextDueDate(credit);
        if (next == null) return false;
        return _daysUntil(next) < 0;
      case CreditsQuickFilter.upcoming:
        final next = getNextDueDate(credit);
        if (next == null) return false;
        final days = _daysUntil(next);
        return days >= 0 && days <= 7;
      case CreditsQuickFilter.cards:
        return credit is CardCredit;
      case CreditsQuickFilter.loans:
        return credit is LoanCredit;
    }
  }

  double _creditUrgency(Credit credit) {
    final next = getNextDueDate(credit);
    if (next == null) return double.negativeInfinity;
    return urgencyScore(
      daysUntilDue: _daysUntil(next),
      amount: getCreditRemainingBalance(credit),
    );
  }

  int _daysUntil(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(date.year, date.month, date.day);
    return due.difference(today).inDays;
  }

  /// Deleting a quota with active (unpaid) purchases referencing it fails
  /// at the DB layer (onDelete: restrict — see tables.dart). This surfaces
  /// that as a clear message instead of letting the raw exception reach
  /// the user.
  Future<void> _confirmDeleteQuota(
      BuildContext context, WidgetRef ref, CommercialQuota quota) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Eliminar "${quota.brand}"?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(commercialQuotasProvider.notifier).delete(quota.id);
    } on QuotaHasActivePurchasesException catch (e) {
      if (context.mounted) {
        final n = e.activeCount;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(n == 1
              ? 'Tiene 1 compra activa registrada en este cupo — ciérrala o muévela primero.'
              : 'Tiene $n compras activas registradas en este cupo — ciérralas o muévelas primero.'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final list = _apply();
    final quotas = showCommercialQuotas
        ? ref.watch(commercialQuotasProvider).valueOrNull ??
            const <CommercialQuota>[]
        : const <CommercialQuota>[];
    // A cupo (even an empty one, just created or left orphaned) must stay
    // visible and manageable from the Activos tab even when every other
    // credit is filtered out or there are none at all — the tab's own
    // "no credits" empty state would otherwise hide it completely.
    if (list.isEmpty && quotas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emptyText,
                style: TextStyle(
                  fontSize: KreditTextSize.body,
                  fontWeight: FontWeight.w600,
                  color: kredit.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              // Bug 5: privacy reassurance notice
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: KreditIconSize.small, color: kredit.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    'Tus datos permanecen en tu dispositivo',
                    style: TextStyle(fontSize: KreditTextSize.caption, color: kredit.textTertiary),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    // Purchases tagged with a CommercialQuota (Totto, Lili Pink, Éxito...)
    // are grouped under one CommercialQuotaCard instead of listed loose —
    // the user sees the brand + disponible/límite, never a flat list of
    // unrelated-looking purchases. Every credit without a quotaId, or whose
    // quotaId doesn't match any quota Kredit actually knows about (data
    // corruption / a quota load error), renders exactly as before instead
    // of silently vanishing.
    final quotaIds = quotas.map((q) => q.id).toSet();
    final purchasesByQuota = <String, List<LoanCredit>>{};
    final ungrouped = <Credit>[];
    for (final credit in list) {
      if (credit is LoanCredit &&
          credit.quotaId != null &&
          quotaIds.contains(credit.quotaId)) {
        purchasesByQuota.putIfAbsent(credit.quotaId!, () => []).add(credit);
      } else {
        ungrouped.add(credit);
      }
    }
    // A cupo's disponible/límite must reflect every purchase it has, not
    // just the ones surviving this tab's search/quick-filter — otherwise
    // searching, or the Vencidos/Próximos filters, would show a heavily
    // used cupo as nearly full. Computed from the unfiltered credits list,
    // independent of `list`/`_apply()` above.
    final allCredits = ref.watch(creditsProvider).valueOrNull ?? const [];
    final allPurchasesByQuota = <String, List<LoanCredit>>{};
    for (final credit in allCredits) {
      if (credit is LoanCredit &&
          credit.quotaId != null &&
          quotaIds.contains(credit.quotaId)) {
        allPurchasesByQuota.putIfAbsent(credit.quotaId!, () => []).add(credit);
      }
    }
    // Every quota renders, even with zero purchases in this tab — an empty
    // cupo (just created, or left orphaned after its only purchase was
    // deleted) must stay visible and manageable (delete button), not
    // disappear silently.
    final quotaCards = quotas;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: quotaCards.length + ungrouped.length,
      itemBuilder: (context, i) {
        if (i < quotaCards.length) {
          final quota = quotaCards[i];
          return _StaggeredEntry(
            index: i,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: CommercialQuotaCard(
                quota: quota,
                purchases: purchasesByQuota[quota.id] ?? const [],
                allPurchases: allPurchasesByQuota[quota.id] ?? const [],
                onTap: () {
                  final all = allPurchasesByQuota[quota.id] ?? const [];
                  if (all.isEmpty) {
                    // Nada que abrir todavía — un cupo vacío (recién
                    // creado, o huérfano tras borrar su única compra)
                    // sigue necesitando una forma de eliminarse.
                    _confirmDeleteQuota(context, ref, quota);
                    return;
                  }
                  final mostRecent = [...all]
                    ..sort((a, b) => b.id.compareTo(a.id));
                  Navigator.of(context).pushNamed(
                    '/credit-detail',
                    arguments: mostRecent.first.id,
                  );
                },
              ),
            ),
          );
        }
        final credit = ungrouped[i - quotaCards.length];
        return _StaggeredEntry(
          index: i,
          child: _CreditWalletListItem(
            credit: credit,
            onTap: () => Navigator.of(context).pushNamed(
              '/credit-detail',
              arguments: credit.id,
            ),
          ),
        );
      },
    );
  }
}

/// Staggered fade+slide-in animation for list items.
/// Uses FadeTransition + SlideTransition (compositor-level, no saveLayer)
/// instead of Opacity + Transform (which force offscreen buffers while
/// animating, causing jank when N items animate simultaneously on load).
class _StaggeredEntry extends StatefulWidget {
  final int index;
  final Widget child;

  const _StaggeredEntry({required this.index, required this.child});

  @override
  State<_StaggeredEntry> createState() => _StaggeredEntryState();
}

class _StaggeredEntryState extends State<_StaggeredEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    final delay = (widget.index * 40).clamp(0, 400);
    if (delay == 0) {
      _ctrl.forward();
    } else {
      Future.delayed(Duration(milliseconds: delay), () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WalletCard list item: tarjeta visual completa + fila de stats debajo
// ─────────────────────────────────────────────────────────────────────────────

class _CreditWalletListItem extends StatefulWidget {
  final Credit credit;
  final VoidCallback onTap;

  const _CreditWalletListItem({
    required this.credit,
    required this.onTap,
  });

  @override
  State<_CreditWalletListItem> createState() => _CreditWalletListItemState();
}

class _CreditWalletListItemState extends State<_CreditWalletListItem> {
  double _scale = 1.0;

  void _setScale(double v) => setState(() => _scale = v);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: GestureDetector(
          onTapDown: (_) => _setScale(0.97),
          onTapUp: (_) {
            _setScale(1.0);
            widget.onTap();
          },
          onTapCancel: () => _setScale(1.0),
          // La tarjeta visual ahora incluye sus propios datos clave (cupo /
          // próximo pago / próxima cuota) integrados en su parte inferior —
          // ya no hay una fila de stats separada debajo. Sin ClipRRect extra
          // aquí: WalletCard ya se recorta a sí mismo con su propia forma
          // por tipo (esquinas cuadradas + muescas para el voucher, radio
          // reducido para una tarjeta real) — envolverlo en otro ClipRRect
          // con un radio uniforme por encima anulaba esa forma específica.
          child: Column(
            children: [
              WalletCard(credit: widget.credit),
              _CreditComparisonStrip(credit: widget.credit),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreditComparisonStrip extends StatelessWidget {
  final Credit credit;

  const _CreditComparisonStrip({required this.credit});

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accent = _stripColor(context, credit);
    final progress = _progressValue(credit);
    final label = _progressLabel(credit);
    final detail = _progressDetail(credit);

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 0),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
      decoration: BoxDecoration(
        color: kredit.bgCard,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(KreditRadius.card),
        ),
        border: Border(
          left: BorderSide(color: kredit.borderCard.withValues(alpha: 0.78)),
          right: BorderSide(color: kredit.borderCard.withValues(alpha: 0.78)),
          bottom: BorderSide(color: kredit.borderCard.withValues(alpha: 0.78)),
        ),
        // Sin boxShadow: el resto de la app (KreditSectionCard, WalletCard,
        // dashboard) usa solo borde tenue, nunca sombra — mantiene esta
        // bandeja consistente con el lenguaje visual "sin cajas pesadas".
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: KreditTextSize.caption,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: kredit.textTertiary,
                  ),
                ),
              ),
              Text(
                detail,
                style: TextStyle(
                  fontSize: KreditTextSize.caption,
                  fontWeight: FontWeight.w800,
                  color: accent,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: kredit.borderCard.withValues(alpha: 0.55),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
      ),
    );
  }
}

double _progressValue(Credit credit) {
  if (credit is CardCredit) {
    if (credit.creditLimit <= 0) return 0;
    return (credit.currentBalance / credit.creditLimit).clamp(0.0, 1.0);
  }
  if (credit is LoanCredit) {
    if (credit.installments.isEmpty) return 0;
    final paid = credit.installments.where((i) => i.paid).length;
    return (paid / credit.installments.length).clamp(0.0, 1.0);
  }
  return 0;
}

String _progressLabel(Credit credit) {
  if (credit is CardCredit) return 'Uso de cupo';
  return 'Progreso pagado';
}

String _progressDetail(Credit credit) {
  final pct = (_progressValue(credit) * 100).round();
  if (credit is CardCredit && credit.creditLimit <= 0) return 'Sin límite';
  if (credit is LoanCredit) {
    final paid = credit.installments.where((i) => i.paid).length;
    return '$paid/${credit.installments.length} · $pct%';
  }
  return '$pct%';
}

Color _stripColor(BuildContext context, Credit credit) {
  final kredit = Theme.of(context).extension<KreditColors>()!;
  final accent = Theme.of(context).colorScheme.primary;
  if (credit is CardCredit) {
    final progress = _progressValue(credit);
    if (progress >= 0.85) return kredit.danger;
    if (progress >= 0.65) return kredit.warning;
    return accent;
  }
  return accent;
}
