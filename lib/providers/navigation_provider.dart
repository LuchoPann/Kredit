import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Available top-level navigation tabs in [RootScaffold].
class AppNavTab {
  static const int dashboard = 0;
  static const int credits = 1;
  static const int stats = 2;
  static const int account = 3;
}

/// Global provider for the active bottom navigation bar tab.
/// Enables any child screen/button (e.g. Dashboard "Ver todos") to
/// smoothly switch tabs without breaking the navigation shell.
final navigationIndexProvider = StateProvider<int>((ref) => AppNavTab.dashboard);
