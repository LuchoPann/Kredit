import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/account/account_screen.dart';
import 'screens/credit_detail/credit_detail_screen.dart';
import 'screens/credits/add_credit_sheet.dart';
import 'screens/credits/credits_list_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/stats/stats_screen.dart';
import 'widgets/kredit_logo.dart';
import 'providers/app_lock_provider.dart';
import 'providers/credits_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/notification_settings_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/widget_privacy_provider.dart';
import 'screens/lock/lock_screen.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'screens/splash_screen.dart';
import 'services/home_widget_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(themePreferencesProvider);
    return MaterialApp(
      title: 'Kredit',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(
        accent: prefs.accentColor,
        bgTone: prefs.bgTone,
        isDarkMode: prefs.isDarkMode,
      ),
      themeAnimationDuration: const Duration(milliseconds: 350),
      themeAnimationCurve: Curves.easeInOutCubic,
      // Spanish locale for built-in widgets (date/time pickers, etc.) — the
      // whole app is written in Spanish, but without this Flutter's own
      // Material widgets default to the device/English locale.
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'CO'), Locale('es')],
      locale: const Locale('es', 'CO'),
      home: const AppLockGate(),
      // Named routes for detail/creation modal views. '/credit-detail' expects
      // the credit id as a String route argument.
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/credit-detail':
            final id = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) => CreditDetailScreen(creditId: id),
              settings: settings,
            );
          case '/add-credit':
            // Fade en vez del slide-desde-la-derecha por defecto de
            // MaterialPageRoute, para que abrir/cerrar "Nuevo Crédito" se
            // sienta como el mismo desvanecimiento usado entre pestañas
            // (_TabFadeLayer) — misma duración/curva, en ambas direcciones
            // porque PageRouteBuilder reutiliza la animación al hacer pop.
            return PageRouteBuilder(
              settings: settings,
              transitionDuration: const Duration(milliseconds: 340),
              reverseTransitionDuration: const Duration(milliseconds: 340),
              pageBuilder: (_, _, _) => const AddCreditSheet(),
              transitionsBuilder: (_, animation, _, child) {
                return FadeTransition(
                  opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                  child: child,
                );
              },
            );
        }
        return null;
      },
    );
  }
}

/// Gate shown at the `MaterialApp.home` root: renders [LockScreen] instead
/// of [RootScaffold] while `appLockProvider.isLocked` is true (e.g. on
/// first launch with a lock method configured, or after returning from
/// background — see `AppLockNotifier`'s `WidgetsBindingObserver`). Purely
/// additive wrapper — does not touch `RootScaffold`'s notification wiring.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key});

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> {
  // Shown until the reveal animation finishes, covering the frame or two
  // where appLockProvider/onboardingProvider still hold their synchronous
  // defaults while their real persisted value loads.
  bool _splashVisible = true;

  @override
  Widget build(BuildContext context) {
    // Real content always mounts immediately so providers/DB load behind splash.
    final isLocked = ref.watch(appLockProvider).isLocked;
    final onboardingAsync = ref.watch(onboardingProvider);

    Widget content;
    if (isLocked) {
      content = const LockScreen();
    } else if (onboardingAsync.isLoading) {
      content = const Scaffold(
        backgroundColor: Colors.black,
        body: SizedBox.shrink(),
      );
    } else {
      final shown = onboardingAsync.value ?? false;
      content = shown ? const RootScaffold() : const WelcomeScreen();
    }

    if (!_splashVisible) return content;

    // Splash sits on top; app content loads underneath.
    return Stack(
      children: [
        content,
        SplashScreen(
          onCompleted: () => setState(() => _splashVisible = false),
        ),
      ],
    );
  }
}

/// Bottom-nav shell: Dashboard / Créditos / Cuenta.
///
/// Also owns wiring for local due-date notifications: initializes the
/// plugin once, then listens to `creditsProvider` (and the notification
/// settings) to keep scheduled reminders in sync whenever the credit list
/// changes — see `services/notification_service.dart`.
class RootScaffold extends ConsumerStatefulWidget {
  const RootScaffold({super.key});

  @override
  ConsumerState<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends ConsumerState<RootScaffold> {
  static const _screens = [
    DashboardScreen(),
    CreditsListScreen(),
    StatsScreen(),
    AccountScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncNotifications());
  }

  Future<void> _syncNotifications() async {
    final service = ref.read(notificationServiceProvider);
    await service.init();
    if (!mounted) return;
    final settings = ref.read(notificationSettingsProvider);
    final credits = ref.read(creditsProvider).value ?? [];
    if (settings.enabled) {
      await service.rescheduleAll(
        credits,
        settings.daysBefore,
        time: settings.reminderTime,
        repeatDaily: settings.repeatDaily,
      );
    } else {
      await service.rescheduleAll(const [], settings.daysBefore);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = ref.watch(navigationIndexProvider);

    ref.listen(creditsProvider, (previous, next) {
      final credits = next.value;
      if (credits == null) return;
      final settings = ref.read(notificationSettingsProvider);
      final service = ref.read(notificationServiceProvider);
      if (settings.enabled) {
        service.rescheduleAll(
          credits,
          settings.daysBefore,
          time: settings.reminderTime,
          repeatDaily: settings.repeatDaily,
        );
      } else {
        service.rescheduleAll(const [], settings.daysBefore);
      }
    });
    ref.listen(notificationSettingsProvider, (previous, next) {
      final credits = ref.read(creditsProvider).value;
      if (credits == null) return;
      final service = ref.read(notificationServiceProvider);
      if (next.enabled) {
        service.rescheduleAll(
          credits,
          next.daysBefore,
          time: next.reminderTime,
          repeatDaily: next.repeatDaily,
        );
      } else {
        service.rescheduleAll(const [], next.daysBefore);
      }
    });
    // Home screen widget (Android): keep the total-debt/next-payment tile in
    // sync with the credit list, independent of the notification listener
    // above. See services/home_widget_service.dart. The widget is visible
    // without unlocking the app, so whether real amounts are shown is
    // gated by `widgetPrivacyProvider` (default: hidden).
    void syncHomeWidget() {
      final credits = ref.read(creditsProvider).value;
      if (credits == null) return;
      final showAmounts = ref.read(widgetPrivacyProvider);
      final themePrefs = ref.read(themePreferencesProvider);
      updateHomeWidget(
        credits,
        showAmounts: showAmounts,
        accentColor: themePrefs.accentColor,
        bgTone: themePrefs.bgTone,
      );
    }

    ref.listen(creditsProvider, (previous, next) => syncHomeWidget());
    ref.listen(widgetPrivacyProvider, (previous, next) => syncHomeWidget());
    // El widget también debe reflejar el acento/tono elegidos en Cuenta >
    // Personalización, no solo los datos de créditos.
    ref.listen(themePreferencesProvider, (previous, next) => syncHomeWidget());
    return Scaffold(
      body: Stack(
        children: [
          // Stylized rotated translucent 'K' emblem watermark embedded in bottom-left app background
          Positioned(
            left: -45,
            bottom: -35,
            child: IgnorePointer(
              child: Transform.rotate(
                angle: -0.22, // ~ -12 degrees rotation
                child: Opacity(
                  opacity: 0.04,
                  child: const KreditLogo(height: 280),
                ),
              ),
            ),
          ),
          // Keep every tab alive, but fade the active one in/out instead of
          // jumping instantly. The screens stay mounted, so scroll position,
          // local filters and form state survive tab changes.
          Positioned.fill(
            child: Stack(
              children: [
                for (var i = 0; i < _screens.length; i++)
                  _TabFadeLayer(
                    active: i == activeIndex,
                    child: _screens[i],
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: activeIndex,
        onTap: (i) => ref.read(navigationIndexProvider.notifier).state = i,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.space_dashboard_outlined),
            activeIcon: Icon(Icons.space_dashboard),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card_outlined),
            activeIcon: Icon(Icons.credit_card),
            label: 'Créditos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Estadísticas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Cuenta',
          ),
        ],
      ),
    );
  }
}

class _TabFadeLayer extends StatelessWidget {
  final bool active;
  final Widget child;

  const _TabFadeLayer({
    required this.active,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // AnimatedOpacity must wrap TickerMode, not the other way around: its
    // fade-out animation needs its own ticker to keep running for the
    // outgoing tab, and TickerMode(enabled: false) disables every ticker in
    // its subtree — including AnimatedOpacity's, if placed underneath it.
    // With that inverted, the outgoing tab froze fully opaque mid-transition
    // and, being painted above lower-index tabs in the Stack, visually
    // blocked navigation back to them (bug reported 2026-09-23).
    return IgnorePointer(
      ignoring: !active,
      child: ExcludeSemantics(
        excluding: !active,
        child: AnimatedOpacity(
          opacity: active ? 1 : 0,
          duration: const Duration(milliseconds: 340),
          curve: Curves.easeOutCubic,
          child: TickerMode(
            enabled: active,
            child: child,
          ),
        ),
      ),
    );
  }
}
