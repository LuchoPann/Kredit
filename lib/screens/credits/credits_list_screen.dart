import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/credit.dart';
import '../../domain/bank_detector.dart';
import '../../domain/credit_calculator.dart';
import '../../providers/credits_filter_provider.dart';
import '../../providers/credits_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/credit_display_utils.dart';
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
            Icon(Icons.error_outline, size: 48, color: kredit.textTertiary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: kredit.textSecondary),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
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
                    hintStyle: TextStyle(fontSize: 13.5, color: kredit.textTertiary),
                    prefixIcon: Icon(Icons.search, size: 20, color: kredit.textSecondary),
                    suffixIcon: filter.query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
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
                  icon: Icon(Icons.sort, color: kredit.textSecondary, size: 22),
                  color: kredit.bgCard,
                  initialValue: filter.sort,
                  onSelected: (v) => ref.read(creditsFilterProvider.notifier).setSort(v),
                  itemBuilder: (context) => const [
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
                        value: CreditsSortOption.name,
                        child: Text('Nombre A-Z'),
                      ),
                    ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Builder(
          builder: (context) {
            // Dynamically extract unique banks that the user actually has in their credits
            final availableBanks = <String>{};
            for (final c in widget.credits) {
              final bank = detectBank(
                lender: c.lender,
                card: c is LoanCredit ? c.card : null,
              );
              availableBanks.add(bank.shortLabel);
            }
            final bankList = availableBanks.toList()..sort();

            if (bankList.isEmpty) return const SizedBox.shrink();

            final kredit = Theme.of(context).extension<KreditColors>()!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Filtrar por entidad',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: kredit.textTertiary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 26,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _BankChip(
                        label: 'Todos',
                        selected: filter.query.isEmpty,
                        onTap: () {
                          _searchController.clear();
                          ref.read(creditsFilterProvider.notifier).setQuery('');
                        },
                      ),
                      ...bankList.map((bank) {
                        final selected = filter.query.toLowerCase() == bank.toLowerCase();
                        return _BankChip(
                          label: bank,
                          selected: selected,
                          onTap: () {
                            final next = selected ? '' : bank;
                            _searchController.text = next;
                            ref.read(creditsFilterProvider.notifier).setQuery(next);
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.label,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
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
              _FilteredList(credits: active, filter: filter, emptyText: 'No tienes créditos activos.'),
              _FilteredList(credits: completed, filter: filter, emptyText: 'No tienes créditos finalizados.'),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilteredList extends StatelessWidget {
  final List<Credit> credits;
  final CreditsFilterState filter;
  final String emptyText;

  const _FilteredList({
    required this.credits,
    required this.filter,
    required this.emptyText,
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

    final sorted = [...result];
    switch (filter.sort) {
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
      case CreditsSortOption.name:
        sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final list = _apply();
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emptyText,
                style: TextStyle(
                  fontSize: 15,
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
                  Icon(Icons.lock_outline, size: 12, color: kredit.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    'Tus datos permanecen en tu dispositivo',
                    style: TextStyle(fontSize: 12, color: kredit.textTertiary),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final credit = list[i];
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

/// Filtro de banco expresado en tipografía pura: un punto circular pequeño
/// (el mismo acento usado para "urgencia" en el dashboard) precede el
/// nombre cuando está seleccionado, y el peso/color del texto marca el
/// estado — sin pastilla rellena ni borde.
class _BankChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BankChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final kredit = Theme.of(context).extension<KreditColors>()!;
    final accentColor = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: InkWell(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              width: selected ? 6 : 0,
              height: 6,
              margin: EdgeInsets.only(right: selected ? 6 : 0),
              decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? accentColor : kredit.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Staggered fade+slide-in animation for list items, so the credits list
/// feels less "flat" on first load — purely presentational, no logic
/// changes. Delay increases per index (capped) so items cascade in.
class _StaggeredEntry extends StatelessWidget {
  final int index;
  final Widget child;

  const _StaggeredEntry({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    final delay = (index * 40).clamp(0, 400);
    return TweenAnimationBuilder<double>(
      key: ValueKey(index),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 16),
            child: child,
          ),
        );
      },
      child: child,
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
          // ya no hay una fila de stats separada debajo. Mismo radio que las
          // demás "surfaces" de nivel superior (KreditRadius.card), en vez de
          // un valor suelto propio de esta pantalla.
          child: ClipRRect(
            borderRadius: BorderRadius.circular(KreditRadius.card),
            child: WalletCard(credit: widget.credit),
          ),
        ),
      ),
    );
  }
}
