import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sort options for the credits list screen, mirroring the `#sort-credits`
/// select in legacy_pwa/index.html (~L197-202).
enum CreditsSortOption { urgency, dueDate, debtDesc, debtAsc, entity, name }

/// Fast comparison filters shown as compact chips in the credits list.
enum CreditsQuickFilter { all, overdue, upcoming, cards, loans }

/// UI-only state for lib/screens/credits/credits_list_screen.dart search box
/// and sort dropdown. Kept separate from credits_provider.dart (data layer,
/// shared with other agents).
class CreditsFilterState {
  final String query;
  final CreditsSortOption sort;
  final CreditsQuickFilter quickFilter;

  const CreditsFilterState({
    this.query = '',
    this.sort = CreditsSortOption.urgency,
    this.quickFilter = CreditsQuickFilter.all,
  });

  CreditsFilterState copyWith({
    String? query,
    CreditsSortOption? sort,
    CreditsQuickFilter? quickFilter,
  }) {
    return CreditsFilterState(
      query: query ?? this.query,
      sort: sort ?? this.sort,
      quickFilter: quickFilter ?? this.quickFilter,
    );
  }
}

class CreditsFilterNotifier extends Notifier<CreditsFilterState> {
  @override
  CreditsFilterState build() => const CreditsFilterState();

  void setQuery(String query) => state = state.copyWith(query: query);

  void setSort(CreditsSortOption sort) => state = state.copyWith(sort: sort);

  void setQuickFilter(CreditsQuickFilter quickFilter) =>
      state = state.copyWith(quickFilter: quickFilter);
}

final creditsFilterProvider =
    NotifierProvider<CreditsFilterNotifier, CreditsFilterState>(
  CreditsFilterNotifier.new,
);
