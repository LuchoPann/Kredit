import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sort options for the credits list screen, mirroring the `#sort-credits`
/// select in legacy_pwa/index.html (~L197-202).
enum CreditsSortOption { dueDate, debtDesc, debtAsc, name }

/// UI-only state for lib/screens/credits/credits_list_screen.dart search box
/// and sort dropdown. Kept separate from credits_provider.dart (data layer,
/// shared with other agents).
class CreditsFilterState {
  final String query;
  final CreditsSortOption sort;

  const CreditsFilterState({
    this.query = '',
    this.sort = CreditsSortOption.dueDate,
  });

  CreditsFilterState copyWith({String? query, CreditsSortOption? sort}) {
    return CreditsFilterState(
      query: query ?? this.query,
      sort: sort ?? this.sort,
    );
  }
}

class CreditsFilterNotifier extends Notifier<CreditsFilterState> {
  @override
  CreditsFilterState build() => const CreditsFilterState();

  void setQuery(String query) => state = state.copyWith(query: query);

  void setSort(CreditsSortOption sort) => state = state.copyWith(sort: sort);
}

final creditsFilterProvider =
    NotifierProvider<CreditsFilterNotifier, CreditsFilterState>(
  CreditsFilterNotifier.new,
);
