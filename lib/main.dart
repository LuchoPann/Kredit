import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'domain/export_import.dart';
import 'providers/commercial_quotas_provider.dart';
import 'providers/last_backup_provider.dart';
import 'screens/account/account_screen.dart';
import 'screens/splash_screen.dart';
import 'services/backup_service.dart';
import 'screens/credit_detail/credit_detail_screen.dart';
import 'screens/credits/add_credit_sheet.dart';
import 'screens/credits/credits_list_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/stats/stats_screen.dart';
import 'widgets/backup_restore_sheet.dart';
import 'widgets/kredit_logo.dart';
import 'widgets/whats_new_sheet.dart';
import 'providers/app_lock_provider.dart';
import 'data/models/credit.dart';
import 'providers/credits_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/notification_settings_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/widget_privacy_provider.dart';
import 'screens/lock/lock_screen.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'providers/database_provider.dart';
import 'providers/shared_preferences_provider.dart';
import 'services/home_widget_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/finanzas/finanzas_cuentas_screen.dart';
import 'screens/finanzas/finanzas_plantillas_screen.dart';
import 'screens/finanzas/finanzas_estadisticas_screen.dart';
import 'providers/entorno_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(themePreferencesProvider);
    return MaterialApp(
      title: 'Krezium',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(
        accent: prefs.accentColor,
        bgTone: prefs.bgTone,
        isDarkMode: prefs.isDarkMode,
      ),
      themeAnimationDuration: const Duration(milliseconds: 150),
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
      home: const bool.fromEnvironment('INTEGRATION_TEST')
          ? AppLockGate()
          : SplashScreen(child: AppLockGate()),
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
  @override
  Widget build(BuildContext context) {
    final isLocked = ref.watch(appLockProvider).isLocked;
    final shown = ref.watch(onboardingProvider);

    const bool kIntegrationTest = bool.fromEnvironment('INTEGRATION_TEST');
    if (isLocked && !kIntegrationTest) return const LockScreen();
    if (!shown && !kIntegrationTest) return const WelcomeScreen();
    return const RootScaffold();
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
  final Set<int> _visitedCreditos = {0};
  final Set<int> _visitedFinanzas = <int>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncNotifications();
      // Muestra novedades una vez por versión, después de que la UI esté lista
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) showWhatsNewIfUpdated(context);
      });
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) _checkAndRunAutoBackup();
      });
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted) showBackupRestoreSheet(context, ref, onlyIfEmpty: true);
      });
      // Listeners registered once here instead of inside build() — avoids
      // re-registering on every rebuild (Riverpod still deduplicates but
      // registering in initState is zero-cost on subsequent builds).
      ref.listen(navigationIndexProvider, (_, next) {
        // Legacy listener kept for external navigation calls
      });
      _loadPreferredEntorno();
      // Single creditsProvider listener: syncs both notifications AND the
      // home-screen widget so there is no double-subscription.
      ref.listen(creditsProvider, (_, next) {
        final credits = next.value;
        if (credits == null) return;
        _rescheduleNotifications(credits);
        _syncHomeWidget(credits);
      });
      ref.listen(notificationSettingsProvider, (_, _) {
        final credits = ref.read(creditsProvider).value;
        if (credits == null) return;
        _rescheduleNotifications(credits);
      });
      ref.listen(widgetPrivacyProvider, (_, _) => _syncHomeWidget());
      ref.listen(themePreferencesProvider, (_, _) => _syncHomeWidget());
    });
  }

  Future<void> _checkAndRunAutoBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('backup_enabled') ?? false;
    if (!enabled) return;

    // Leer directamente de SharedPreferences para evitar race condition con
    // LastBackupNotifier._load() (async): el provider puede valer null aunque
    // ya exista un backup guardado.
    final raw = prefs.getString('last_backup_at');
    final lastBackup = raw != null ? DateTime.tryParse(raw) : null;
    final now = DateTime.now();

    final frequency = prefs.getString('backup_frequency') ?? 'weekly';
    final bool isDue;
    if (lastBackup == null) {
      isDue = true;
    } else if (frequency == 'daily') {
      isDue = now.difference(lastBackup).inHours >= 24;
    } else if (frequency == 'monthly') {
      isDue = now.difference(lastBackup).inDays >= 30;
    } else if (frequency == 'biweekly') {
      isDue = now.difference(lastBackup).inDays >= 15;
    } else {
      // weekly
      isDue = now.difference(lastBackup).inDays >= 7;
    }
    if (!isDue) return;

    try {
      final credits = ref.read(creditsProvider).value ?? [];
      final quotas = ref.read(commercialQuotasProvider).value ?? [];
      final json = exportStateToJson(credits, quotas);
      final mode = prefs.getString('backup_mode') ?? 'overwrite';
      final file = await BackupService.saveBackup(json, newFile: mode == 'new_file');
      if (file != null) {
        await ref.read(lastBackupProvider.notifier).markBackedUpNow();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Respaldo automático completado')),
          );
        }
      }
    } catch (e) {
      debugPrint('Auto-backup failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo completar el respaldo automático'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _loadPreferredEntorno() async {
    final entorno = await loadPreferredEntorno();
    if (mounted) {
      ref.read(entornoProvider.notifier).state = entorno;
    }
  }

  Future<void> _syncNotifications() async {
    final service = ref.read(notificationServiceProvider);
    await service.init();
    if (!mounted) return;
    final credits = ref.read(creditsProvider).value ?? [];
    _rescheduleNotifications(credits);
  }

  void _rescheduleNotifications(List<Credit> credits) {
    final s = ref.read(notificationSettingsProvider);
    final service = ref.read(notificationServiceProvider);
    if (s.enabled) {
      service.rescheduleAll(credits, s.daysBefore, time: s.reminderTime, repeatDaily: s.repeatDaily);
      // Alertas de mora: cuotas vencidas sin pago registrado.
      final db = ref.read(databaseProvider);
      service.scheduleOverdueAlerts(credits, db);
      // Recordatorio de cierre de extracto (tarjetas cuyo corte es hoy).
      service.scheduleCutoffReminders(credits, time: s.reminderTime);
    } else {
      service.rescheduleAll(const [], s.daysBefore);
    }
  }

  // Home screen widget (Android): keep the total-debt/next-payment tile in
  // sync with the credit list, independent of the notification listener
  // above. See services/home_widget_service.dart. The widget is visible
  // without unlocking the app, so whether real amounts are shown is
  // gated by `widgetPrivacyProvider` (default: hidden).
  void _syncHomeWidget([List<Credit>? credits]) {
    final c = credits ?? ref.read(creditsProvider).value;
    if (c == null) return;
    final showAmounts = ref.read(widgetPrivacyProvider);
    final themePrefs = ref.read(themePreferencesProvider);
    updateHomeWidget(c, showAmounts: showAmounts, accentColor: themePrefs.accentColor, bgTone: themePrefs.bgTone);
  }

  Set<int> _visitedForEntorno(Entorno e) =>
      e == Entorno.creditos ? _visitedCreditos : _visitedFinanzas;

  @override
  Widget build(BuildContext context) {
    final entorno = ref.watch(entornoProvider);
    final creditosTab = ref.watch(creditosTabProvider);
    final finanzasTab = ref.watch(finanzasTabProvider);

    final isCreditos = entorno == Entorno.creditos;
    final currentTab = isCreditos ? creditosTab : finanzasTab;
    final isAccount = currentTab == 3;

    final creditosScreens = const [
      DashboardScreen(),
      CreditsListScreen(),
      StatsScreen(),
    ];
    final finanzasScreens = const [
      FinanzasCuentasScreen(),
      FinanzasPlantillasScreen(),
      FinanzasEstadisticasScreen(),
    ];
    final screens = isCreditos ? creditosScreens : finanzasScreens;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            left: -45,
            bottom: -35,
            child: IgnorePointer(
              child: Transform.rotate(
                angle: -0.22,
                child: const Opacity(
                  opacity: 0.04,
                  child: AppLogo(height: 280),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Stack(
              children: [
                for (var i = 0; i < screens.length; i++)
                  if (_visitedForEntorno(entorno).contains(i))
                    _TabFadeLayer(
                      active: !isAccount && i == currentTab,
                      child: screens[i],
                    )
                  else
                    const SizedBox.shrink(),
                _TabFadeLayer(
                  active: isAccount,
                  child: const AccountScreen(),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildDualNav(context, entorno, currentTab, isAccount),
    );
  }

  Widget _buildDualNav(BuildContext context, Entorno entorno, int currentTab, bool isAccount) {
    final isCreditos = entorno == Entorno.creditos;
    int navIndex;
    if (isAccount) {
      navIndex = 4;
    } else if (currentTab <= 1) {
      navIndex = currentTab;
    } else {
      navIndex = currentTab + 1;
    }

    final cs = Theme.of(context).colorScheme;
    // Ícono que indica el destino (a dónde irías al presionar), no el origen
    final switchIconData = isCreditos
        ? Icons.account_balance_wallet_outlined  // en créditos → ir a finanzas
        : Icons.credit_card_outlined;            // en finanzas → ir a créditos
    final switchIcon = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cs.primaryContainer,
      ),
      child: Icon(switchIconData, color: cs.onPrimaryContainer, size: 22),
    );

    return NavigationBarTheme(
      data: NavigationBarThemeData(
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
        ),
        iconTheme: WidgetStateProperty.all(const IconThemeData(size: 22)),
      ),
      child: NavigationBar(
        selectedIndex: navIndex,
        onDestinationSelected: (i) {
          if (i == 2) {
            // switch entorno
            final next = isCreditos ? Entorno.finanzas : Entorno.creditos;
            ref.read(entornoProvider.notifier).state = next;
            savePreferredEntorno(next);
            return;
          }
          final tab = i > 2 ? i - 1 : i;
          if (tab == 3) {
            if (isCreditos) {
              ref.read(creditosTabProvider.notifier).state = 3;
            } else {
              ref.read(finanzasTabProvider.notifier).state = 3;
            }
          } else {
            if (isCreditos) {
              setState(() => _visitedCreditos.add(tab));
              ref.read(creditosTabProvider.notifier).state = tab;
            } else {
              setState(() => _visitedFinanzas.add(tab));
              ref.read(finanzasTabProvider.notifier).state = tab;
            }
          }
        },
        destinations: [
          if (isCreditos) ...[
            const NavigationDestination(icon: Icon(Icons.space_dashboard_outlined), selectedIcon: Icon(Icons.space_dashboard), label: 'Inicio'),
            const NavigationDestination(icon: Icon(Icons.credit_card_outlined), selectedIcon: Icon(Icons.credit_card), label: 'Créditos'),
          ] else ...[
            const NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Cuentas'),
            const NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Plantillas'),
          ],
          NavigationDestination(icon: switchIcon, selectedIcon: switchIcon, label: ''),
          const NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Estadísticas'),
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Cuenta'),
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
